# Azal Soft Platform — Project Proposal, Impact, Deliverables and Financial System

*Water-utility management for community-run well networks · Al-Radhma district, Ibb governorate, Yemen*

---

## 1. Executive summary

Azal Soft Platform is a water-utility management system for small, community-run well networks. It replaces paper ledgers and scattered spreadsheets with one record of every subscriber, every meter reading, every cycle, and every riyal that moves. The pilot covers **10 wells and 60 subscribers** in **Al-Radhma district, Ibb governorate, Yemen**, operated by the local well committees under the district council.

The platform is already built and running: a Flutter application for Android and web, a Firebase backend, an Arabic right-to-left interface, and a double-entry accounting layer derived from the operational data. The financial system is not a separate module bolted on at the end — billing, collections and well costs are posted to a chart of accounts and can be read as one accounting tree per well or consolidated across all wells.

---

## 2. The problem

| # | Problem | Consequence |
|---|---|---|
| 1 | Consumption is recorded on paper per cycle | Records are lost, rewriting errors are common, and no one can reconstruct a past cycle |
| 2 | No reliable subscriber ledger | Disputes over "I already paid" cannot be settled with evidence |
| 3 | Water is billed by estimate, not by meter | Revenue leaks and consumption is invisible |
| 4 | Well running costs (fuel, operator, maintenance) are untracked | No one knows whether a well covers its own cost |
| 5 | Committee reporting to the council is verbal | The district cannot plan, compare wells, or justify tariffs |
| 6 | No shared register of wells, villages and subscribers | Duplicate subscribers across wells; no district-wide view |

---

## 3. The solution

One platform, three layers:

| Layer | What it does |
|---|---|
| **Operational** | Wells, villages, subscribers, meter readings per cycle, consumption in m³ |
| **Financial** | Subscriber accounts, well cash accounts, operator dues, expenses, vouchers, invoices, receivables |
| **Analytical** | Cycle reports, account reports (daily / monthly / yearly), per-well profitability, consolidated accounting tree, district dashboard |

The operating cycle in the application:

```
Open cycle → Meter readings → Consumption (m³) → Charge to subscriber account
           → Receipt / payment voucher → Close cycle → Reports
```

Every step writes to the same database, so a report is never a re-entry of numbers — it is a read of what actually happened.

---

## 4. Pilot scope

| Item | Value |
|---|---|
| Wells | 10 |
| Subscribers | 60 |
| Location | Al-Radhma district, Ibb governorate |
| Operating unit | Well committee; district council as governing body |
| Currency | Yemeni Rial (YER) |
| Consumption unit | m³ |
| Reading cycle | per well, opened and closed by the supervisor |
| Platforms | Android application + web application |

---

## 5. The financial system

### 5.1 Model

A **per-well double-entry ledger** with a consolidated roll-up. Every well is an accounting entity; the district is the consolidation level. Subscriber billing and collections happen inside the well entity, so a well can be judged on its own result without manual allocation.

### 5.2 Chart of accounts

| Code | Account | Source of the figure |
|---|---|---|
| **1000** | **Assets** | |
| 1100 | Cash and funds | |
| 1101 | Well cash box | accounts where type = cash |
| 1200 | Receivables | |
| 1201 | Subscriber receivables | accounts carrying a customerId |
| 1900 | Unclassified accounts | unrecognised type — never dropped, always flagged |
| **2000** | **Liabilities** | |
| 2100 | Operator dues | |
| 2101 | Well operator payable | accounts where type = worker |
| **3000** | **Equity** | |
| 3100 | Result for the period | Revenue − Expenses (computed, display only) |
| **4000** | **Revenue** | |
| 4100 | Water sales | |
| 4101 | Metered water sales | accounts where type = sales |
| **5000** | **Expenses** | |
| 5100 | Well expenses | |
| 5101 | Fuel, operator, maintenance | accounts where type = expenses |

### 5.3 Posting rules

- Both entry shapes found in the data are read: single-account postings (accountId + debit / credit + transaction type) and explicit double entries (debitAccountId / creditAccountId + amount).
- Entries are de-duplicated by document id, so a report never counts the same riyal twice.
- A debit and a credit must exist for every economic event; the report surfaces the difference when they do not.
- Accounts that carry a stored balance but no entries fall back to that stored balance, with an explicit warning — legacy figures are never silently dropped.
- Anything that cannot be classified lands in **1900 Unclassified** and is counted, not hidden.

### 5.4 Controls

| Control | Rule |
|---|---|
| Trial balance | Total debit = total credit, shown in the footer |
| Accounting equation | Assets − Liabilities = Revenue − Expenses, shown as Balanced / Unbalanced with the exact difference |
| Completeness | Unclassified accounts and unassigned postings are counted and reported |
| Period integrity | All time / This year / This month, with entries outside the window excluded and undated entries kept |
| Transparency | One-click CSV export of the whole tree for auditors and donors |

### 5.5 Reporting outputs

| Report | Question it answers |
|---|---|
| Cycle report (daily / monthly / yearly) | How much water moved, and who consumed it |
| Account report (daily / monthly / yearly) | What each account received and paid |
| Accounting tree (per well / all wells) | What the well owns, owes, earned and spent |
| Energy consumption report | How much fuel and power went into each m³ |
| Invoice and voucher documents | The paper trail behind every figure |
| District dashboard | Which wells are healthy and which need attention |

---

## 6. Impact

### 6.1 Before and after

| Dimension | Before | After |
|---|---|---|
| Reading capture | Paper, lost, unverifiable | Digital, timestamped, per meter |
| Subscriber balance | Verbal claim | Ledger with a running balance and an invoice |
| Revenue leakage | Unknown, unbounded | Metered consumption and receivables visible per subscriber |
| Well cost awareness | None | Cost per m³ and result per well available on demand |
| Cycle closing | Ad hoc | Explicit open / close with a report at closure |
| Council reporting | Verbal | Exported statements a non-specialist can read |
| Audit | Impossible | Every figure traceable to an entry |

### 6.2 Who benefits

- **Well committees** — know their cash position, who owes, and what the well actually costs.
- **Subscribers** — a receipt and a readable balance instead of a dispute.
- **District council** — comparable, evidence-based data for 10 wells, and a template for the district.
- **Donors and programmes** — verifiable consumption and financial records rather than self-reported numbers.

### 6.3 Scale path

| Level | Wells | Subscribers | Basis |
|---|---|---|---|
| Pilot | 10 | 60 | This proposal |
| District | — | ~15,000 | Extension over Al-Radhma |
| Governorate | — | ~45,000 | Extension over Ibb |

The unit economics used in the pitch: **1,500 USD for 720 readings**, i.e. about **2.08 USD per reading** at pilot scale. This is a planning assumption, to be confirmed against real operating cost.

---

## 7. Deliverables

### 7.1 Application

| Module | Status |
|---|---|
| Authentication and role-based entry (supervisor, main supervisor) | Delivered |
| Wells, villages and subscriber registration | Delivered |
| Cycle management: open, readings, close | Delivered |
| Meter reading by camera with OCR (on-device) | Delivered |
| Subscriber accounts, invoices, receipt and payment vouchers | Delivered |
| Reports: cycle, account, energy, accounting tree | Delivered |
| Consolidated accounting tree, per well and across wells | Delivered |
| Arabic RTL interface, English UI labels | Delivered |
| Web build deployed on Firebase Hosting, Android build | Delivered |

### 7.2 Non-software deliverables

| Output | Purpose |
|---|---|
| Water Challenge Brief (Arabic and English) | Programme submission |
| Accounting documentation | How the tree is derived, which fields feed which code |
| Deployment and hosting guide | Handover to a technical operator |
| Data contract for supervisors and cycles | What must be recorded, and what "not measured" means |

---

## 8. How success is measured

| KPI | Target direction |
|---|---|
| Share of readings captured digitally | Up toward 100% |
| Cycles closed with a report | Up toward every cycle |
| Unclassified accounts in the tree | Down toward zero |
| Unbalanced periods | Down toward zero |
| Collection ratio (receipts / billed) | Up |
| Cost per m³ per well | Known, then down |
| Time to produce a council report | From days to minutes |

---

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| Weak or intermittent connectivity | Web assets cached after first load; accounting derived from stored data, no live dependency for reporting |
| Missing data confused with poor performance | The system labels missing measurements as "not measured", never as failure |
| Legacy records without account types | Unclassified bucket plus explicit warnings, so nothing disappears silently |
| Tariff not officially agreed | Treated as an open item: the system records billed amounts, the tariff decision stays with the council |
| Device cost for committees | One shared Android device per well is sufficient; the web build covers desktop review |
| Trust in a new system | CSV export of every report, so the committee can verify outside the app |

---

## 10. Open items

1. Official water tariff per m³ and per usage type.
2. Official subscriber count per well, to reconcile against the register.
3. Who signs a cycle closure, and what document records it.
4. Whether well committees join the Ibb branch structure.
5. Confirmation of the unit cost per reading.

---

## 11. Next steps

| Step | Owner | Output |
|---|---|---|
| Deploy the current release to the hosted site | Technical | Live URL serving the current build |
| Register the 10 wells and 60 subscribers | Committees | Complete register |
| Run one full cycle on one well | Supervisor | End-to-end evidence, from reading to report |
| Cross-check one well's accounting tree against its account report | Technical + committee | Confirmed figures |
| Present the district summary to the council | Project lead | Decision on district extension |

---

*Prepared on the basis of the deployed application and the data model in the repository. Figures marked as assumptions are planning inputs, not measured results.*
