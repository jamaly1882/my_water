# Integrated Project Proposal — Azal Soft Platform

**Project:** Azal Soft Platform (technical name: my_water) — Digital Water-Well Operations and Financial Management Platform  
**Proposal purpose:** Explain the idea, the problem it addresses, expected impact, project outputs, and the financial system to be used.  
**Pilot scope:** 10 wells and 60 subscribers, as defined in the current project brief. The pilot scope and baseline figures should be confirmed with the participating well committees before launch.

> **Evidence note:** “Available in the current application” describes functionality represented in the repository. Impact figures below are proposed pilot targets, not results already achieved. No field-performance or financial-impact results should be claimed until measured.

---

## 1. Executive Summary

Many community water wells rely on handwritten meter readings, paper invoices, and separate cash records. This makes it difficult to verify bills, track collections and expenses, detect water or revenue losses, and plan maintenance using reliable information.

**Azal Soft Platform** is a mobile and web platform for managing the operating cycle of a community water well. It connects subscriber and meter records, meter readings, consumption, billing, receipts, payments, well accounts, energy records, and management reports. Meter photos can be processed through an OCR workflow with image-quality checks and confidence review; uncertain readings should be checked by a person before billing.

The project proposes a controlled pilot across **10 wells and 60 subscribers**. It will establish verified opening readings and balances, run regular reading and billing cycles, record financial transactions with supporting vouchers, and measure operational and financial indicators. The pilot will produce evidence for deciding whether and how to expand the system.

**In one sentence:** Azal Soft Platform turns fragmented paper-based well operations into a traceable digital record linking **meter reading → consumption → bill → collection → well fund → operating expense → management decision**.

## 2. The Idea and the Problem

### Current challenges

1. **Reading errors and disputes:** readings may be handwritten, copied later, or entered without a photo or an auditable review trail.
2. **Unclear bills:** subscribers may not be able to see how their billed consumption was calculated.
3. **Weak cash control:** revenue, cash on hand, expenses, and worker payments may be recorded separately, making reconciliation difficult.
4. **Unknown operating cost:** fuel, solar-energy, maintenance, and water-volume information may not be combined to show the cost of supplying water.
5. **Late or incomplete management information:** committees and supervisors may only see delayed summaries, limiting timely action.

### Proposed solution

The platform provides a shared operating record for each well. A typical cycle is:

1. Register wells, subscribers, meters, and opening readings.
2. Open a reading cycle and capture each meter reading, preferably with a photo.
3. Review OCR suggestions; confirm or correct uncertain readings before approval.
4. Calculate consumption from current and previous readings and prepare bills using the well’s approved tariff.
5. Record collections and expenses using numbered vouchers and link them to the relevant well and cycle where applicable.
6. Review cash, account balances, consumption, energy, and activity reports.
7. Close and archive the cycle, retaining the supporting records for review.

## 3. Who Benefits

| Stakeholder | Expected value |
|---|---|
| Subscribers and households | More understandable bills, fewer avoidable reading disputes, and a way to verify recorded usage. |
| Well committees and operators | A clearer view of collections, available funds, expenses, worker obligations, and operating performance. |
| Meter readers and supervisors | Faster recording, fewer transcription steps, and a consistent review process for questionable readings. |
| Local authorities and water-sector partners | More timely and comparable reports to support oversight, maintenance planning, and evidence-based assistance. |
| Funders and development partners | Better traceability of pilot activity and a measurable basis for deciding whether to support expansion. |

## 4. Expected Impact and How It Will Be Measured

Impacts should be assessed against a documented baseline, not assumed. Before the first digital cycle, the pilot team should record the existing process, time spent, typical billing disputes, collection records, and the quality of available cash books.

| Impact area | Pilot indicator | Proposed success threshold* |
|---|---|---|
| Reading efficiency | Median time from starting a reading to saving it | Under 30 seconds for a routine reading, after staff are trained |
| Reading coverage | Share of registered subscribers with an approved reading in each cycle | At least 95% per cycle |
| OCR workflow | Share of readings accepted without manual correction | At least 85%; a target for testing, not a guaranteed current result |
| Reading quality | Error rate after human review against a verified reference reading | At most 1%, measured on the pilot sample |
| Billing transparency | Bills linked to a subscriber, cycle, and approved reading | 100% of pilot bills, subject to complete data entry |
| Financial control | Receipts and payments supported by a numbered voucher and recorded against the correct well | At least 95% during the pilot, with exceptions documented |
| Reconciliation | Difference between system fund balance and physically counted cash | Investigated and documented at every close; target zero unexplained difference |
| Operational insight | Availability of cycle, finance, and energy reports for participating wells | Reported for every completed cycle where source data is available |
| User experience | Number and type of billing or cash-record disputes | Establish baseline, then compare monthly; do not promise a reduction before measurement |

\*These are proposed pilot targets. They are not verified achievements. For a reliable trial, the project brief proposes four monthly cycles, giving up to **240 reading opportunities** (60 subscribers × 4 cycles), provided all subscribers are active and readings are captured.

### Expected wider effects

- **Greater accountability:** a transaction or reading can be traced to a well, cycle, user, and supporting document where those fields are recorded.
- **Better cost visibility:** combining water-volume and energy records can help estimate energy cost per unit of water once reliable cost and volume data are entered.
- **More informed maintenance:** trends in consumption, energy use, and expenses can help identify wells that need investigation.
- **Potentially stronger service continuity:** earlier visibility of cash shortfalls or rising operating costs can support timely decisions. This is an intended contribution, not a guaranteed outcome; continuity also depends on equipment, water availability, governance, and funding.

## 5. Project Outputs

### Digital and operational outputs

1. A configured registry for pilot locations, wells, subscribers, meters, and user roles.
2. Verified opening meter readings and an agreed subscriber list for each participating well.
3. A repeatable reading-cycle process with reading review and approval.
4. Cycle-based consumption and billing records, using a tariff approved by the responsible well committee.
5. Numbered receipt and payment vouchers linked to well-level accounts and transactions.
6. Well-level financial, cycle, and energy reports, plus management summaries based on available data.
7. Trained well staff and a short operating guide covering readings, corrections, billing, cash handling, and cycle closure.
8. A pilot evaluation report comparing baseline and post-implementation indicators, including limitations and user feedback.

### Evidence package for the pilot

- Coverage and completion by well and cycle.
- Reading time, OCR acceptance, manual correction, and reference-check results.
- Billing and collection summaries.
- Voucher completeness and cash-reconciliation differences.
- Energy and operating-cost data where the well can provide reliable records.
- Feedback from subscribers, readers, and committee members.
- A documented recommendation to continue, adjust, or expand.

## 6. Financial System to Use

### Recommendation

Use a **simple well-level double-entry bookkeeping system**, supported by the platform’s accounts, debit/credit transactions, receipt and payment vouchers, and accounting-tree reports. Keep each well’s records separate for day-to-day accountability, while allowing authorized management to view consolidated summaries.

This is the proposed project control system; it is not a substitute for local statutory accounting, tax advice, or an accountant’s approval. Before official financial reporting, an accountant familiar with the applicable local requirements should validate the chart of accounts, opening balances, tariff treatment, and reporting format.

### Suggested chart of accounts

| Code | Account | Type / purpose |
|---|---|---|
| 1101 | Well cash fund | Asset — cash held for the well |
| 1201 | Subscriber receivables | Asset — approved bills not yet collected |
| 2101 | Worker amounts payable | Liability — approved but unpaid worker amounts |
| 3100 | Accumulated result / opening balance | Equity or fund balance; opening treatment to be confirmed by the accountant |
| 4101 | Water sales revenue | Revenue — billed water sales, recorded according to the approved accounting policy |
| 5101 | Well operating expenses | Expense — repairs, supplies, and other operating costs |
| 5110 | Energy and fuel expense | Expense — diesel, electricity, or other energy costs; use separate subaccounts if useful |
| 5120 | Maintenance expense | Expense — preventive and corrective maintenance |

The application already has well-level account types for **sales, cash/fund, expenses, and worker/operator**, receipt and payment vouchers, debit/credit transaction records, and an accounting-tree view. The list above is a recommended standardized presentation; confirm the exact account names, codes, and posting behavior before the pilot.

### Basic posting rules

| Event | Debit | Credit | Supporting record |
|---|---|---|---|
| Approved water bill (if using accrual accounting) | Subscriber receivables | Water sales revenue | Approved bill and reading-cycle reference |
| Subscriber payment | Well cash fund | Subscriber receivables | Numbered receipt voucher linked to subscriber and bill/cycle |
| Well expense paid in cash | Relevant expense account | Well cash fund | Numbered payment voucher, description, date, and receipt where available |
| Worker amount approved but not yet paid | Relevant worker/labour expense | Worker amounts payable | Approval or payroll record |
| Worker amount paid | Worker amounts payable | Well cash fund | Payment voucher linked to the approval |
| Opening cash | Well cash fund | Opening fund balance / equity | Signed opening cash count and approval |

If the committee and accountant choose **cash-basis** reporting instead, water revenue should be recognized when collected and the method must be applied consistently. Do not mix cash-basis and accrual-basis reports without clearly labeling them. The current software’s records and reports should be tested against the chosen policy before results are presented as formal financial statements.

### Essential financial controls

- Assign a unique voucher number; do not delete posted records to hide corrections. Reverse or adjust them with a reason and a reference to the original entry.
- Separate roles where practical: one person records, another approves payments, and a committee member reviews the reconciliation.
- Require date, well, amount, account, description, and supporting evidence for each transaction.
- Count the physical cash and reconcile it to the system at each cycle close; record the signatories and any difference.
- Reconcile subscriber balances to approved bills and receipts.
- Keep opening balances signed and verified before migration; do not estimate them silently.
- Restrict account access by role and back up/export records regularly.
- Report financial amounts in the currency actually used by the well and document the currency and reporting period. Do not assume a tariff, exchange rate, tax, or fee without local approval.

### Financial sustainability model

The pilot should first establish its actual cost base rather than set an unsupported price. Track:

- one-time setup and data-cleaning costs;
- staff training and support time;
- devices, connectivity, hosting, and maintenance costs;
- ongoing administration per well and per cycle; and
- measurable savings or avoided costs, such as reduced re-entry time or fewer unresolved discrepancies.

Possible long-term funding approaches to test with well committees and partners include a modest per-well service fee, an institution/utility subscription, or donor-funded deployment and training. Any fee must be transparently approved, affordable for the community, and kept separate from water tariffs unless the responsible authority explicitly approves combining them. The pilot should not claim that the platform itself increases revenue until collection and cost data demonstrate that result.

## 7. Pilot Implementation Plan

| Phase | Main activities | Deliverable / decision gate |
|---|---|---|
| 1. Readiness | Confirm participating wells, committee consent, user roles, tariff policy, data privacy approach, and baseline process. | Signed pilot scope and baseline sheet |
| 2. Setup | Configure wells and subscribers; verify meter numbers and opening readings; create well accounts and access. | Validated registry and signed opening balances |
| 3. Training | Train readers, supervisors, and finance approvers; practice a reading, correction, receipt, payment, and reconciliation. | Trained users and completed practice cycle |
| 4. Pilot operations | Run four monthly cycles where feasible; review readings before bills; record vouchers and expenses; close and reconcile each cycle. | Four cycle datasets and monthly review notes |
| 5. Evaluation | Compare results with baseline; review user feedback, exceptions, data gaps, and financial records. | Pilot evaluation and scale-up recommendation |

## 8. Risks and Mitigation

| Risk | Mitigation |
|---|---|
| Incorrect subscriber or opening-meter data | Verify records on site and have the subscriber or committee acknowledge opening readings. |
| OCR error or poor image quality | Treat OCR as an aid, not an authority; require human review for low-confidence readings and preserve corrections. |
| Missing or inconsistent financial records | Train users on vouchers, reconcile every cycle, and document exceptions rather than inventing missing data. |
| Limited connectivity or device access | Agree an offline/contingency procedure and enter deferred records with their original dates and supporting evidence. |
| Resistance or low adoption | Involve committees and readers in setup, demonstrate subscriber benefits, and offer practical training and support. |
| Privacy or unauthorized access | Collect only necessary information, use role-based access, and agree who may view subscriber and financial data. |
| Unclear ownership of funds or tariff decisions | Keep the platform separate from governance decisions; committees or competent authorities approve tariffs, spending, and financial policy. |

## 9. Conclusion and Request

Azal Soft Platform offers a practical way to connect water operations and financial records at the well level. The project’s value is not merely replacing paper with a screen; it is creating a reviewable chain from a meter reading to a bill and from a financial transaction to the well’s fund and operating reports.

The immediate request is to approve a bounded pilot covering **10 wells and 60 subscribers**, appoint a project focal person and well-level approvers, provide access to verified meter and opening-balance data, and support four operating cycles where feasible. The pilot will then provide evidence on usability, reading quality, financial control, and operating costs before any scale-up decision.

## 10. Budget and Financial Forecast Template

No project budget or tariff has been assumed in this proposal because local prices, staff rates, exchange rates, and existing equipment have not been provided. Complete this table with quotations and actual operating data before requesting funds.

### Pilot budget worksheet

| Budget line | Unit | Quantity | Unit cost | Total | Evidence / notes |
|---|---:|---:|---:|---:|---|
| Initial data verification and setup | day / well | ___ | ___ | ___ | Include travel if required |
| Training and user support | session / person | ___ | ___ | ___ | List trainees and duration |
| Phones or tablets (only if needed) | device | ___ | ___ | ___ | Deduct available devices |
| Internet / data | month / user | ___ | ___ | ___ | Confirm coverage and provider |
| Hosting and technical maintenance | month | ___ | ___ | ___ | Record actual service cost |
| Meter-reading operations | cycle / well | ___ | ___ | ___ | Include reader time and transport |
| Financial review / accountant validation | day | ___ | ___ | ___ | Validate opening balances and reporting policy |
| Monitoring and evaluation | day / cycle | ___ | ___ | ___ | Baseline, close-out, and feedback |
| Contingency | percentage | ___ | ___ | ___ | Explain approved percentage |
| **Total pilot budget** |  |  |  | **___** | State currency and price date |

### Sustainability calculation

Use actual pilot data to calculate:

- **Annual operating cost per well** = annual platform, support, connectivity, and administration costs ÷ active wells.
- **Cost per subscriber served** = annual operating cost ÷ active subscribers.
- **Cost recovery ratio** = recurring project income ÷ recurring operating cost.
- **Break-even number of wells** = fixed annual operating costs ÷ (annual fee per well − variable annual cost per well), if the fee is higher than variable cost.

A fee or subsidy model is viable only if it covers the real recurring costs without making water service unaffordable. Report the assumed number of active wells, payment collection rate, currency, and time period alongside every forecast.

## 11. Short Pitch

**Azal Soft Platform is a digital operations and financial-management platform for community water wells. It connects meter readings, consumption, billing, collections, expenses, energy records, and reports in one traceable workflow. Through a proposed pilot across 10 wells and 60 subscribers, we will test whether the system can improve reading coverage and transparency, strengthen voucher-based cash control, and give well committees more reliable information for operating decisions. We will measure the results against a documented baseline and use a simple, well-level double-entry bookkeeping approach validated by a local accountant before formal financial reporting.**
